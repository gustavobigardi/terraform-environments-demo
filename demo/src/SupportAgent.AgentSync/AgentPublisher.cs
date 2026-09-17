using System.ClientModel;
using System.Text;
using Azure.AI.Extensions.OpenAI;
using Azure.AI.Projects;
using Azure.AI.Projects.Agents;
using Azure.Identity;
using OpenAI.Files;
using OpenAI.Responses;
using OpenAI.VectorStores;

namespace SupportAgent.AgentSync;

public sealed class AgentPublisher
{
    private readonly AgentManifest _manifest;
    private readonly string _environmentKey;
    private readonly AgentAdministrationClient _agents;
    private readonly ProjectFilesClient _files;
    private readonly ProjectVectorStoresClient _vectorStores;

    public AgentPublisher(Uri projectEndpoint, DefaultAzureCredential credential, AgentManifest manifest, string environmentKey)
    {
        _manifest = manifest;
        _environmentKey = environmentKey.ToLowerInvariant();

        var project = new AIProjectClient(projectEndpoint, credential);
        _agents = project.AgentAdministrationClient;
        _files = project.ProjectOpenAIClient.GetProjectFilesClient();
        _vectorStores = project.ProjectOpenAIClient.GetProjectVectorStoresClient();
    }

    private string VectorStoreNamePrefix => $"{_manifest.VectorStorePrefix}-{_environmentKey}-";

    public async Task<string> SyncAsync(int keepVersions)
    {
        var summary = new StringBuilder($"## Agente `{_manifest.Name}` no ambiente `{_environmentKey}`\n\n");

        var vectorStore = await EnsureVectorStoreAsync(summary);
        var latest = await GetLatestVersionAsync();

        var unchanged = latest is not null
            && latest.Metadata.TryGetValue("instructions-sha", out var instructionsSha) && instructionsSha == _manifest.InstructionsHash
            && latest.Metadata.TryGetValue("vector-store", out var storeId) && storeId == vectorStore.Id
            && latest.Metadata.TryGetValue("model", out var model) && model == _manifest.Model;

        if (unchanged)
        {
            summary.AppendLine($"- Prompt e base sem mudanças: mantendo a versão **{latest!.Version}**.");
            return summary.ToString();
        }

        var definition = new DeclarativeAgentDefinition(_manifest.Model)
        {
            Instructions = _manifest.Instructions,
        };
        definition.Tools.Add(ResponseTool.CreateFileSearchTool([vectorStore.Id]));

        var creation = new ProjectsAgentVersionCreationOptions(definition)
        {
            Description = _manifest.Description,
        };
        creation.Metadata["environment-key"] = _environmentKey;
        creation.Metadata["instructions-sha"] = _manifest.InstructionsHash;
        creation.Metadata["knowledge-sha"] = _manifest.KnowledgeHash;
        creation.Metadata["vector-store"] = vectorStore.Id;
        creation.Metadata["model"] = _manifest.Model;
        creation.Metadata["git-sha"] = Environment.GetEnvironmentVariable("GITHUB_SHA") ?? "local";

        ProjectsAgentVersion created = await _agents.CreateAgentVersionAsync(_manifest.Name, creation);
        summary.AppendLine($"- Nova versão publicada: **{created.Version}** (prompt `{_manifest.InstructionsHash}`, base `{_manifest.KnowledgeHash}`).");

        await PruneOldVersionsAsync(keepVersions, summary);
        return summary.ToString();
    }

    public async Task<string> CleanupAsync()
    {
        var summary = new StringBuilder($"## Limpeza do agente no ambiente `{_environmentKey}`\n\n");

        try
        {
            await _agents.DeleteAgentAsync(_manifest.Name);
            summary.AppendLine($"- Agente `{_manifest.Name}` e versões removidos.");
        }
        catch (ClientResultException ex) when (ex.Status == 404)
        {
            summary.AppendLine("- Agente não existia.");
        }

        await foreach (var store in _vectorStores.GetVectorStoresAsync(new VectorStoreCollectionOptions()))
        {
            if (store.Name?.StartsWith(VectorStoreNamePrefix, StringComparison.Ordinal) == true)
            {
                await DeleteVectorStoreWithFilesAsync(store.Id);
                summary.AppendLine($"- Vector store `{store.Name}` e arquivos removidos.");
            }
        }

        return summary.ToString();
    }

    /// <summary>Reaproveita o vector store se o hash da base não mudou; senão cria um novo e descarta os antigos.</summary>
    private async Task<VectorStore> EnsureVectorStoreAsync(StringBuilder summary)
    {
        var expectedName = VectorStoreNamePrefix + _manifest.KnowledgeHash;
        VectorStore? current = null;
        var stale = new List<VectorStore>();

        await foreach (var store in _vectorStores.GetVectorStoresAsync(new VectorStoreCollectionOptions()))
        {
            if (store.Name == expectedName && store.Status == VectorStoreStatus.Completed)
            {
                current = store;
            }
            else if (store.Name?.StartsWith(VectorStoreNamePrefix, StringComparison.Ordinal) == true)
            {
                stale.Add(store);
            }
        }

        if (current is not null)
        {
            summary.AppendLine($"- Base de conhecimento sem mudanças (`{expectedName}`).");
        }
        else
        {
            var fileIds = new List<string>();
            foreach (var file in _manifest.Knowledge)
            {
                await using var content = File.OpenRead(file.Path);
                OpenAIFile uploaded = await _files.UploadFileAsync(content, file.Name, FileUploadPurpose.Assistants);
                fileIds.Add(uploaded.Id);
            }

            var options = new VectorStoreCreationOptions { Name = expectedName };
            foreach (var id in fileIds)
            {
                options.FileIds.Add(id);
            }
            options.Metadata["environment-key"] = _environmentKey;
            options.Metadata["knowledge-sha"] = _manifest.KnowledgeHash;

            current = await _vectorStores.CreateVectorStoreAsync(options);
            current = await WaitUntilIndexedAsync(current.Id);
            summary.AppendLine($"- Base reindexada: {fileIds.Count} arquivos em `{expectedName}`.");
        }

        foreach (var store in stale)
        {
            await DeleteVectorStoreWithFilesAsync(store.Id);
            summary.AppendLine($"- Vector store antigo removido: `{store.Name}`.");
        }

        return current;
    }

    private async Task<VectorStore> WaitUntilIndexedAsync(string vectorStoreId)
    {
        var deadline = DateTimeOffset.UtcNow.AddMinutes(5);
        while (true)
        {
            VectorStore store = await _vectorStores.GetVectorStoreAsync(vectorStoreId);
            if (store.Status == VectorStoreStatus.Completed && store.FileCounts.InProgress == 0)
            {
                if (store.FileCounts.Failed > 0)
                {
                    throw new InvalidOperationException($"{store.FileCounts.Failed} arquivo(s) falharam na indexação.");
                }

                return store;
            }

            if (DateTimeOffset.UtcNow > deadline)
            {
                throw new TimeoutException($"Vector store {vectorStoreId} não terminou a indexação em 5 minutos.");
            }

            await Task.Delay(TimeSpan.FromSeconds(3));
        }
    }

    private async Task DeleteVectorStoreWithFilesAsync(string vectorStoreId)
    {
        var fileIds = new List<string>();
        await foreach (var file in _vectorStores.GetVectorStoreFilesAsync(vectorStoreId, new VectorStoreFileCollectionOptions()))
        {
            fileIds.Add(file.FileId);
        }

        await _vectorStores.DeleteVectorStoreAsync(vectorStoreId);

        foreach (var fileId in fileIds)
        {
            try
            {
                await _files.DeleteFileAsync(fileId);
            }
            catch (ClientResultException ex) when (ex.Status == 404)
            {
            }
        }
    }

    private async Task<ProjectsAgentVersion?> GetLatestVersionAsync()
    {
        try
        {
            ProjectsAgentVersion? latest = null;
            await foreach (var version in _agents.GetAgentVersionsAsync(_manifest.Name))
            {
                if (latest is null || version.CreatedAt > latest.CreatedAt)
                {
                    latest = version;
                }
            }

            return latest;
        }
        catch (ClientResultException ex) when (ex.Status == 404)
        {
            return null;
        }
    }

    private async Task PruneOldVersionsAsync(int keepVersions, StringBuilder summary)
    {
        var versions = new List<ProjectsAgentVersion>();
        await foreach (var version in _agents.GetAgentVersionsAsync(_manifest.Name))
        {
            versions.Add(version);
        }

        foreach (var old in versions.OrderByDescending(v => v.CreatedAt).Skip(keepVersions))
        {
            await _agents.DeleteAgentVersionAsync(_manifest.Name, old.Version);
            summary.AppendLine($"- Versão antiga removida: {old.Version}.");
        }
    }
}
