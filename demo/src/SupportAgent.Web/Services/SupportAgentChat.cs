using System.Runtime.CompilerServices;
using Azure.AI.Extensions.OpenAI;
using Azure.AI.Projects;
using Azure.Identity;
using Microsoft.Extensions.Options;
using OpenAI.Responses;

namespace SupportAgent.Web.Services;

/// <summary>Eventos emitidos durante o streaming da resposta do agente.</summary>
public abstract record ChatStreamEvent;

public sealed record ResponseStarted(string ResponseId) : ChatStreamEvent;

public sealed record SearchPerformed(IReadOnlyList<string> Queries) : ChatStreamEvent;

public sealed record TextDelta(string Text) : ChatStreamEvent;

public sealed record MessageCompleted(string Text, IReadOnlyList<string> Citations) : ChatStreamEvent;

/// <summary>
/// Conversa com o agente publicado no projeto Foundry DESTE ambiente.
/// A app nunca cria o agente: ela só o referencia pelo nome (sempre a versão mais recente).
/// </summary>
public sealed class SupportAgentChat(IOptions<FoundryOptions> options, DefaultAzureCredential credential)
{
    private readonly FoundryOptions _options = options.Value;
    private ProjectResponsesClient? _responses;

    public bool IsConfigured =>
        Uri.TryCreate(_options.ProjectEndpoint, UriKind.Absolute, out _) &&
        !string.IsNullOrWhiteSpace(_options.AgentName);

    public async IAsyncEnumerable<ChatStreamEvent> AskAsync(
        string question,
        string? previousResponseId,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        var request = new CreateResponseOptions
        {
            PreviousResponseId = previousResponseId,
        };
        request.InputItems.Add(ResponseItem.CreateUserMessageItem(question));

        await foreach (var update in GetClient().CreateResponseStreamingAsync(request, cancellationToken))
        {
            switch (update)
            {
                case StreamingResponseCreatedUpdate created:
                    yield return new ResponseStarted(created.Response.Id);
                    break;

                case StreamingResponseOutputTextDeltaUpdate delta:
                    yield return new TextDelta(delta.Delta);
                    break;

                // Mostrar as consultas feitas ao vector store deixa visível o efeito do prompt na busca.
                case StreamingResponseOutputItemDoneUpdate { Item: FileSearchCallResponseItem search }:
                    yield return new SearchPerformed(search.Queries.ToList());
                    break;

                case StreamingResponseOutputItemDoneUpdate { Item: MessageResponseItem message }:
                    yield return ToCompletedMessage(message);
                    break;

                case StreamingResponseErrorUpdate error:
                    throw new InvalidOperationException($"O agente retornou erro {error.Code}: {error.Message}");

                case StreamingResponseFailedUpdate failed:
                    throw new InvalidOperationException($"A resposta falhou: {failed.Response.Error?.Message}");
            }
        }
    }

    private static MessageCompleted ToCompletedMessage(MessageResponseItem message)
    {
        var text = string.Concat(message.Content.Select(part => part.Text));

        var citations = message.Content
            .SelectMany(part => part.OutputTextAnnotations)
            .OfType<FileCitationMessageAnnotation>()
            .Select(annotation => annotation.Filename ?? annotation.FileId)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        return new MessageCompleted(text, citations);
    }

    private ProjectResponsesClient GetClient()
    {
        if (_responses is not null)
        {
            return _responses;
        }

        if (!IsConfigured)
        {
            throw new InvalidOperationException("Configure Foundry:ProjectEndpoint e Foundry:AgentName.");
        }

        var project = new AIProjectClient(new Uri(_options.ProjectEndpoint!), credential);
        _responses = project.ProjectOpenAIClient.GetProjectResponsesClientForAgent(
            new AgentReference(_options.AgentName!, null),
            null);

        return _responses;
    }
}
