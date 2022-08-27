using JustSaying.Messaging.Interrogation;
using JustSaying.Models;

namespace JustSaying.Messaging;

public interface IMessagePublisher<in T> : IInterrogable, IStartable
    where T : Message
{
    Task PublishAsync(T message, CancellationToken cancellationToken);
    Task PublishAsync(T message, PublishMetadata metadata, CancellationToken cancellationToken);
}
