package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RoomEquipmentDto {
    private Long id;
    private Long apartmentRoomId;
    private String name;
    private String description;
    private List<RoomImageDto> images = new ArrayList<>();
}
