package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApartmentRoomCompleteDto {
    private Long id;
    private Long apartmentId;
    private String roomName;
    private RoomTypeDto roomType;
    private List<RoomFieldValueDto> fieldValues = new ArrayList<>();
    private List<RoomEquipmentDto> equipments = new ArrayList<>();
    private List<RoomImageDto> images = new ArrayList<>();
}
