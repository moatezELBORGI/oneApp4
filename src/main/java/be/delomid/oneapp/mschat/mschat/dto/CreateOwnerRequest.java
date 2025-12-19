package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateOwnerRequest {
    private String fname;
    private String lname;
    private String email;
    private String phoneNumber;
    private String buildingId;
    private List<String> apartmentIds;
}
