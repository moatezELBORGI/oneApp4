package be.delomid.oneapp.mschat.mschat.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateTenantQuickRequest {

    @NotBlank(message = "Le prénom est obligatoire")
    private String fname;

    @NotBlank(message = "Le nom est obligatoire")
    private String lname;

    @NotBlank(message = "L'email est obligatoire")
    @Email(message = "Format d'email invalide")
    private String email;

    @NotBlank(message = "Le numéro de téléphone est obligatoire")
    private String phoneNumber;
}
