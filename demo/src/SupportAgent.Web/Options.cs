namespace SupportAgent.Web;

/// <summary>Identificação do ambiente em que a app está rodando (main, tesc-001, local...).</summary>
public sealed class EnvironmentOptions
{
    public const string SectionName = "Environment";

    public string Key { get; set; } = "local";

    /// <summary>main, preview ou local.</summary>
    public string Type { get; set; } = "local";

    public string Branch { get; set; } = "local";

    public bool IsPreview => string.Equals(Type, "preview", StringComparison.OrdinalIgnoreCase);
}

/// <summary>Projeto Foundry e agente usados por este ambiente.</summary>
public sealed class FoundryOptions
{
    public const string SectionName = "Foundry";

    public string? ProjectEndpoint { get; set; }

    public string? ProjectName { get; set; }

    public string? AgentName { get; set; }
}
