package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.CreateTenantQuickRequest;
import be.delomid.oneapp.mschat.mschat.dto.ResidentDto;
import be.delomid.oneapp.mschat.mschat.model.AccountStatus;
import be.delomid.oneapp.mschat.mschat.model.Resident;
import be.delomid.oneapp.mschat.mschat.model.UserRole;
import be.delomid.oneapp.mschat.mschat.repository.ResidentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class TenantQuickCreateService {

    private final ResidentRepository residentRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;

    private static final String CHAR_LOWER = "abcdefghijklmnopqrstuvwxyz";
    private static final String CHAR_UPPER = CHAR_LOWER.toUpperCase();
    private static final String NUMBER = "0123456789";
    private static final String SPECIAL_CHAR = "@#$%&*!";
    private static final String PASSWORD_CHARS = CHAR_LOWER + CHAR_UPPER + NUMBER + SPECIAL_CHAR;
    private static final SecureRandom random = new SecureRandom();

    @Transactional
    public ResidentDto createTenantQuick(CreateTenantQuickRequest request) {
        log.info("Creating new tenant: {}", request.getEmail());

        if (residentRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new IllegalArgumentException("Un utilisateur avec cet email existe déjà");
        }

        String generatedPassword = generateSecurePassword(12);

        Resident tenant = Resident.builder()
                .idUsers(UUID.randomUUID().toString())
                .fname(request.getFname())
                .lname(request.getLname())
                .email(request.getEmail())
                .password(passwordEncoder.encode(generatedPassword))
                .phoneNumber(request.getPhoneNumber())
                .role(UserRole.RESIDENT)
                .accountStatus(AccountStatus.ACTIVE)
                .isEnabled(true)
                .build();

        tenant = residentRepository.save(tenant);

        try {
            sendWelcomeEmail(tenant, generatedPassword);
            log.info("Welcome email sent to {}", tenant.getEmail());
        } catch (Exception e) {
            log.error("Failed to send welcome email to {}", tenant.getEmail(), e);
        }

        return convertToDto(tenant);
    }

    private String generateSecurePassword(int length) {
        StringBuilder password = new StringBuilder(length);

        password.append(CHAR_LOWER.charAt(random.nextInt(CHAR_LOWER.length())));
        password.append(CHAR_UPPER.charAt(random.nextInt(CHAR_UPPER.length())));
        password.append(NUMBER.charAt(random.nextInt(NUMBER.length())));
        password.append(SPECIAL_CHAR.charAt(random.nextInt(SPECIAL_CHAR.length())));

        for (int i = 4; i < length; i++) {
            password.append(PASSWORD_CHARS.charAt(random.nextInt(PASSWORD_CHARS.length())));
        }

        char[] passwordArray = password.toString().toCharArray();
        for (int i = passwordArray.length - 1; i > 0; i--) {
            int j = random.nextInt(i + 1);
            char temp = passwordArray[i];
            passwordArray[i] = passwordArray[j];
            passwordArray[j] = temp;
        }

        return new String(passwordArray);
    }

    private void sendWelcomeEmail(Resident tenant, String password) {
        String subject = "Bienvenue sur la plateforme OneApp";
        String body = String.format(
                "Bonjour %s %s,\n\n" +
                "Votre compte a été créé avec succès sur la plateforme OneApp.\n\n" +
                "Voici vos identifiants de connexion:\n" +
                "Email: %s\n" +
                "Mot de passe: %s\n\n" +
                "Nous vous recommandons de changer votre mot de passe lors de votre première connexion.\n\n" +
                "Cordialement,\n" +
                "L'équipe OneApp",
                tenant.getFname(),
                tenant.getLname(),
                tenant.getEmail(),
                password
        );

        emailService.sendEmail(tenant.getEmail(), subject, body);
    }

    private ResidentDto convertToDto(Resident resident) {
        return ResidentDto.builder()
                .idUsers(resident.getIdUsers())
                .fname(resident.getFname())
                .lname(resident.getLname())
                .email(resident.getEmail())
                .phoneNumber(resident.getPhoneNumber())
                .picture(resident.getPicture())
                .role(resident.getRole().name())
                .accountStatus(resident.getAccountStatus().name())
                .isEnabled(resident.getIsEnabled())
                .build();
    }
}
