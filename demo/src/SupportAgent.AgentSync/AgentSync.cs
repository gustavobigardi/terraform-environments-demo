using Azure.Identity;
using SupportAgent.AgentSync;

// Publica (sync) ou remove (cleanup) o agente de suporte no projeto Foundry de um ambiente.
//
//   dotnet run --project src/SupportAgent.AgentSync -- sync    --endpoint <url> --env-key tesc-001 --agent-dir agent
//   dotnet run --project src/SupportAgent.AgentSync -- cleanup --endpoint <url> --env-key tesc-001 --agent-dir agent

var arguments = CommandLine.Parse(args);
if (arguments is null)
{
    Console.Error.WriteLine("""
        uso: AgentSync <sync|cleanup> --endpoint <project-endpoint> --env-key <chave> [--agent-dir agent] [--keep-versions 5]
        """);
    return 2;
}

try
{
    var manifest = AgentManifest.Load(arguments.AgentDirectory);
    var credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
    {
        ExcludeInteractiveBrowserCredential = true,
    });

    var publisher = new AgentPublisher(new Uri(arguments.Endpoint), credential, manifest, arguments.EnvironmentKey);

    var summary = arguments.Command switch
    {
        "sync" => await publisher.SyncAsync(arguments.KeepVersions),
        "cleanup" => await publisher.CleanupAsync(),
        _ => throw new InvalidOperationException($"Comando desconhecido: {arguments.Command}"),
    };

    Console.WriteLine(summary);
    StepSummary.Append(summary);
    return 0;
}
catch (Exception ex)
{
    Console.Error.WriteLine($"::error::{ex.Message}");
    Console.Error.WriteLine(ex);
    return 1;
}
