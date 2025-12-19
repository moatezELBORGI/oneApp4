package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InventoryRoomEntryDto {
    private String id;
    private String inventoryId;
    private String roomId;
    private String sectionName;
    private String description;
    private Integer orderIndex;
    @Builder.Default
    private List<InventoryRoomPhotoDto> photos = new ArrayList<>();
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
