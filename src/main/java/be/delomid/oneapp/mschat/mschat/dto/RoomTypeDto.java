package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RoomTypeDto {
    private Long id;
    private String name;
    private Long buildingId;
    private List<RoomTypeFieldDefinitionDto> fieldDefinitions = new ArrayList<>();
}
