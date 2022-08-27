using JustSaying.Messaging.Interrogation;
using JustSaying.Models;

namespace JustSaying.Messaging;

public class TypedMessagePublisher<T> : IMessagePublisher<T>
    where T : Message
{
    private readonly IMessagePublisher _messagePublisher;

    public TypedMessagePublisher(IMessagePublisher messagePublisher)
    {
        if (messagePublisher is JustSayingBus jsBus && jsBus.RegisteredMessageTypes.Contains(typeof(T)))
            throw new InvalidOperationException($"No message publisher registered for type {nameof(T)}");
        _messagePublisher = messagePublisher;
    }

    public async Task PublishAsync(T message, CancellationToken cancellationToken) =>
        await _messagePublisher.PublishAsync(message, cancellationToken);

    public async Task PublishAsync(T message, PublishMetadata metadata, CancellationToken cancellationToken) =>
        await _messagePublisher.PublishAsync(message, metadata, cancellationToken);

    public InterrogationResult Interrogate() =>
        _messagePublisher.Interrogate();

    public async Task StartAsync(CancellationToken stoppingToken) =>
        await _messagePublisher.StartAsync(stoppingToken);
}
