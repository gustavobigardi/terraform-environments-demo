namespace SupportAgent.AgentSync;

public sealed record CommandLine(string Command, string Endpoint, string EnvironmentKey, string AgentDirectory, int KeepVersions)
{
    public static CommandLine? Parse(string[] args)
    {
        if (args.Length == 0 || args[0] is not ("sync" or "cleanup"))
        {
            return null;
        }

        var options = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        for (var i = 1; i < args.Length - 1; i += 2)
        {
            if (!args[i].StartsWith("--", StringComparison.Ordinal))
            {
                return null;
            }

            options[args[i][2..]] = args[i + 1];
        }

        if (!options.TryGetValue("endpoint", out var endpoint) || !Uri.IsWellFormedUriString(endpoint, UriKind.Absolute) ||
            !options.TryGetValue("env-key", out var environmentKey) || string.IsNullOrWhiteSpace(environmentKey))
        {
            return null;
        }

        var keepVersions = options.TryGetValue("keep-versions", out var keep) && int.TryParse(keep, out var parsed) ? parsed : 5;

        return new CommandLine(
            args[0],
            endpoint,
            environmentKey,
            options.GetValueOrDefault("agent-dir", "agent"),
            Math.Max(1, keepVersions));
    }
}

public static class StepSummary
{
    /// <summary>Escreve no resumo do job quando roda no GitHub Actions.</summary>
    public static void Append(string markdown)
    {
        var path = Environment.GetEnvironmentVariable("GITHUB_STEP_SUMMARY");
        if (!string.IsNullOrEmpty(path))
        {
            File.AppendAllText(path, markdown + Environment.NewLine);
        }
    }
}
