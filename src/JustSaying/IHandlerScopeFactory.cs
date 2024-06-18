namespace JustSaying;

public interface IHandlerScopeFactory
{
    /// <summary>
    /// Creates a service resolution scope that resolves services with a scoped lifetime.
    /// </summary>
    /// <returns>An <see cref="IHandlerScope"/> that can be used to resolve services with a scoped lifetime.</returns>
    IHandlerScope CreateScope();
}
