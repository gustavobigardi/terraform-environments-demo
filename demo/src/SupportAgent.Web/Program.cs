using Azure.Identity;
using Azure.Monitor.OpenTelemetry.AspNetCore;
using SupportAgent.Web;
using SupportAgent.Web.Components;
using SupportAgent.Web.Services;

var builder = WebApplication.CreateBuilder(args);

// Tudo que diferencia um ambiente do outro chega por app settings criadas pelo Terraform.
builder.Services.Configure<EnvironmentOptions>(builder.Configuration.GetSection(EnvironmentOptions.SectionName));
builder.Services.Configure<FoundryOptions>(builder.Configuration.GetSection(FoundryOptions.SectionName));

// Managed identity na Web App; az login / VS Code na máquina local.
builder.Services.AddSingleton(_ => new DefaultAzureCredential());
builder.Services.AddSingleton<SupportAgentChat>();

builder.Services.AddHealthChecks();

if (!string.IsNullOrWhiteSpace(builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"]))
{
    builder.Services.AddOpenTelemetry().UseAzureMonitor();
}

builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    app.UseHsts();
}
app.UseStatusCodePagesWithReExecute("/not-found", createScopeForStatusCodePages: true);
app.UseHttpsRedirection();

app.UseAntiforgery();

app.MapHealthChecks("/healthz");
app.MapStaticAssets();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
