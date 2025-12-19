package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AddChampRequest {
    private String libelle;
    private Integer ordre;
    private String typeChamp;
    private String valeur;
    private String etat;
    private Integer note;
    private Boolean checkbox;
    private String remarque;
}
