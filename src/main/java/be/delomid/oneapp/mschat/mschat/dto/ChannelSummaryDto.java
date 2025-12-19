package be.delomid.oneapp.mschat.mschat.dto;

public record ChannelSummaryDto(
        String aiSummary,           // Résumé généré par GPT
        Long totalMessages,
        Long textMessages,
        Long mediaMessages,
        Long distinctMembers,
        Long totalReactions
) {}