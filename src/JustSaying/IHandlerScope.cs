using JustSaying.Fluent;

namespace JustSaying;

public interface IHandlerScope : IDisposable
{
    /// <summary>
    /// Gets a scoped IHandlerResolver that can handle scoped service lifetimes.
    /// </summary>
    IHandlerResolver HandlerResolver { get; }
}
