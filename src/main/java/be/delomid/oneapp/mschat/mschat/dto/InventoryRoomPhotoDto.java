package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InventoryRoomPhotoDto {
    private String id;
    private String roomEntryId;
    private String photoUrl;
    private String caption;
    private Integer orderIndex;
    private LocalDateTime createdAt;
}
