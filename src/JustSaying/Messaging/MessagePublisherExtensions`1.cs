using System.ComponentModel;
using JustSaying.Models;

namespace JustSaying.Messaging;

[EditorBrowsable(EditorBrowsableState.Never)]
public static class MessagePublisherTExtensions
{
    public static Task PublishAsync<T>(this IMessagePublisher<T> publisher, T message)
        where T : Message
    {
        return publisher.PublishAsync(message, CancellationToken.None);
    }

    public static async Task PublishAsync<T>(this IMessagePublisher<T> publisher,
        T message, PublishMetadata metadata)
        where T : Message
    {
        if (publisher == null)
        {
            throw new ArgumentNullException(nameof(publisher));
        }

        await publisher.PublishAsync(message, metadata, CancellationToken.None)
            .ConfigureAwait(false);
    }

    public static async Task PublishAsync<T>(this IMessagePublisher<T> publisher,
        T message, CancellationToken cancellationToken)
        where T : Message
    {
        if (publisher == null)
        {
            throw new ArgumentNullException(nameof(publisher));
        }

        await publisher.PublishAsync(message, null, cancellationToken)
            .ConfigureAwait(false);
    }
}
