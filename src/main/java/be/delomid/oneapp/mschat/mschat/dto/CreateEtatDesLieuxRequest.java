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
public class CreateEtatDesLieuxRequest {
    private String appartementId;
    private String type;
    private LocalDateTime dateVisite;
    private String expertNom;
    private String locataireNom;
    private String proprietaireNom;
}
