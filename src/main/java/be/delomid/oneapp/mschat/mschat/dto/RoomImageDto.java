package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoomImageDto {
    private Long id;
    private Long apartmentRoomId;
    private Long equipmentId;
    private String imageUrl;
    private Integer displayOrder;
}
