package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateChampRequest {
    private String valeur;
    private String etat;
    private Integer note;
    private Boolean checkbox;
    private String remarque;
}
