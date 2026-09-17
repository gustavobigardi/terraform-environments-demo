using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace SupportAgent.AgentSync;

/// <summary>Definição versionada do agente: agent/agent.json + instructions.md + knowledge/.</summary>
public sealed record AgentManifest(
    string Name,
    string Description,
    string Model,
    string Instructions,
    IReadOnlyList<KnowledgeFile> Knowledge,
    string VectorStorePrefix)
{
    /// <summary>Hash do conteúdo da base: só recria o vector store quando algum arquivo muda.</summary>
    public string KnowledgeHash => Hash(string.Join('\n', Knowledge.Select(file => $"{file.Name}:{file.Sha256}")));

    public string InstructionsHash => Hash(Instructions);

    public static AgentManifest Load(string agentDirectory)
    {
        var manifestPath = Path.Combine(agentDirectory, "agent.json");
        using var stream = File.OpenRead(manifestPath);
        var json = JsonSerializer.Deserialize<ManifestJson>(stream, new JsonSerializerOptions(JsonSerializerDefaults.Web))
            ?? throw new InvalidOperationException($"{manifestPath} inválido.");

        var instructions = File.ReadAllText(Path.Combine(agentDirectory, json.InstructionsFile)).Trim();

        var knowledge = Directory
            .EnumerateFiles(Path.Combine(agentDirectory, json.KnowledgeFolder), "*.md")
            .Order(StringComparer.Ordinal)
            .Select(path => new KnowledgeFile(Path.GetFileName(path), path, Hash(File.ReadAllText(path))))
            .ToList();

        if (knowledge.Count == 0)
        {
            throw new InvalidOperationException("Nenhum arquivo .md encontrado na base de conhecimento.");
        }

        return new AgentManifest(json.Name, json.Description, json.Model, instructions, knowledge, json.VectorStorePrefix);
    }

    private static string Hash(string value) =>
        Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(value)))[..12];

    private sealed record ManifestJson(
        string Name,
        string Description,
        string Model,
        string InstructionsFile,
        string KnowledgeFolder,
        string VectorStorePrefix);
}

public sealed record KnowledgeFile(string Name, string Path, string Sha256);
