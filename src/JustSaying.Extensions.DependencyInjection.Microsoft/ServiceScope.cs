using JustSaying.Fluent;
using JustSaying.Messaging.MessageHandling;

namespace JustSaying;

internal sealed class HandlerProviderHandlerScope : IHandlerScope, IDisposable
{
    private readonly Microsoft.Extensions.DependencyInjection.IServiceScope _scope;
    private readonly HandlerProviderResolver _providerResolver;

    /// <inheritdoc />
    public IServiceResolver ServiceResolver => _providerResolver;

    public HandlerProviderHandlerScope(Microsoft.Extensions.DependencyInjection.IServiceScope scope)
    {
        _scope = scope;
        _providerResolver = new HandlerProviderResolver(scope.ServiceProvider);
    }

    public void Dispose()
    {
        _scope.Dispose();
    }

    public IHandlerAsync<T> ResolveHandler<T>(HandlerResolutionContext context) =>
        _providerResolver.ResolveHandler<T>(context);
}
