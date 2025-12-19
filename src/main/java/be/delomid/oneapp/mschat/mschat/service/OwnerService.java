package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.ApartmentDto;
import be.delomid.oneapp.mschat.mschat.dto.CreateOwnerRequest;
import be.delomid.oneapp.mschat.mschat.dto.ResidentDto;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class OwnerService {

    private final ResidentRepository residentRepository;
    private final ApartmentRepository apartmentRepository;
    private final BuildingRepository buildingRepository;
    private final ResidentBuildingRepository residentBuildingRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public ResidentDto createOwner(CreateOwnerRequest request, String creatorId) {
        Resident creator = residentRepository.findById(creatorId)
                .orElseThrow(() -> new RuntimeException("Creator not found"));

        if (creator.getRole() != UserRole.BUILDING_ADMIN && creator.getRole() != UserRole.SUPER_ADMIN) {
            throw new RuntimeException("Only building admins can create owners");
        }

        Building building = buildingRepository.findById(request.getBuildingId())
                .orElseThrow(() -> new RuntimeException("Building not found"));

        if (residentRepository.existsByEmail((request.getEmail()))) {
            throw new RuntimeException("User with this email already exists");
        }

        String generatedPassword = UUID.randomUUID().toString().substring(0, 8);

        Resident owner = Resident.builder()
                .idUsers(UUID.randomUUID().toString())
                .fname(request.getFname())
                .lname(request.getLname())
                .email(request.getEmail())
                .phoneNumber(request.getPhoneNumber())
                .password(passwordEncoder.encode(generatedPassword))
                .role(UserRole.OWNER)
                .accountStatus(AccountStatus.ACTIVE)
                .isEnabled(true)
                .build();

        owner = residentRepository.save(owner);

        ResidentBuilding residentBuilding = ResidentBuilding.builder()
                 .resident(owner)
                .building(building)
                .build();
        residentBuildingRepository.save(residentBuilding);

        if (request.getApartmentIds() != null && !request.getApartmentIds().isEmpty()) {
            for (String apartmentId : request.getApartmentIds()) {
                Apartment apartment = apartmentRepository.findById(apartmentId)
                        .orElseThrow(() -> new RuntimeException("Apartment not found: " + apartmentId));

                if (!apartment.getBuilding().getBuildingId().equals(request.getBuildingId())) {
                    throw new RuntimeException("Apartment does not belong to the specified building");
                }

                apartment.setOwner(owner);
                apartmentRepository.save(apartment);
            }
        }

        log.info("Created owner {} with temporary password: {}", owner.getEmail(), generatedPassword);

        return convertToDto(owner);
    }

    public List<ResidentDto> getOwnersByBuilding(String buildingId) {
        Building building = buildingRepository.findById(buildingId)
                .orElseThrow(() -> new RuntimeException("Building not found"));

        List<Apartment> apartments = apartmentRepository.findByBuildingBuildingId(buildingId);

        return apartments.stream()
                .filter(apt -> apt.getOwner() != null)
                .map(Apartment::getOwner)
                .distinct()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public void assignApartmentToOwner(String apartmentId, String ownerId, String adminId) {
        Resident admin = residentRepository.findById(adminId)
                .orElseThrow(() -> new RuntimeException("Admin not found"));

        if (admin.getRole() != UserRole.BUILDING_ADMIN && admin.getRole() != UserRole.SUPER_ADMIN) {
            throw new RuntimeException("Only building admins can assign apartments");
        }

        Resident owner = residentRepository.findById(ownerId)
                .orElseThrow(() -> new RuntimeException("Owner not found"));

        Apartment apartment = apartmentRepository.findById(apartmentId)
                .orElseThrow(() -> new RuntimeException("Apartment not found"));

        apartment.setOwner(owner);
        apartmentRepository.save(apartment);
    }

    public List<ApartmentDto> getMyOwnedApartments(String userId, String buildingId) {
        List<Apartment> apartments = apartmentRepository.findByBuilding_IdBuildingAndOwner_IdUsers(buildingId, userId);

        return apartments.stream()
                .map(this::convertApartmentToDto)
                .collect(Collectors.toList());
    }

    private ApartmentDto convertApartmentToDto(Apartment apartment) {
        ResidentDto ownerDto = null;
        if (apartment.getOwner() != null) {
            Resident owner = apartment.getOwner();
            ownerDto = ResidentDto.builder()
                    .idUsers(owner.getIdUsers())
                    .fname(owner.getFname())
                    .lname(owner.getLname())
                    .email(owner.getEmail())
                    .phoneNumber(owner.getPhoneNumber())
                    .picture(owner.getPicture())
                    .role(UserRole.valueOf(owner.getRole().name()))
                    .build();
        }

        ResidentDto tenantDto = null;
        if (apartment.getTenant() != null) {
            Resident tenant = apartment.getTenant();
            tenantDto = ResidentDto.builder()
                    .idUsers(tenant.getIdUsers())
                    .fname(tenant.getFname())
                    .lname(tenant.getLname())
                    .email(tenant.getEmail())
                    .phoneNumber(tenant.getPhoneNumber())
                    .picture(tenant.getPicture())
                    .role(UserRole.valueOf(tenant.getRole().name()))
                    .build();
        }

        ResidentDto residentDto = null;
        if (apartment.getResident() != null) {
            Resident resident = apartment.getResident();
            residentDto = ResidentDto.builder()
                    .idUsers(resident.getIdUsers())
                    .fname(resident.getFname())
                    .lname(resident.getLname())
                    .email(resident.getEmail())
                    .phoneNumber(resident.getPhoneNumber())
                    .picture(resident.getPicture())
                    .role(UserRole.valueOf(resident.getRole().name()))
                    .build();
        }

        return ApartmentDto.builder()
                .id(apartment.getIdApartment())
                .idApartment(apartment.getIdApartment())
                .apartmentLabel(apartment.getApartmentLabel())
                .apartmentNumber(apartment.getApartmentNumber())
                .apartmentFloor(apartment.getApartmentFloor())
                .floor(apartment.getApartmentFloor())
                .livingAreaSurface(apartment.getLivingAreaSurface())
                .numberOfRooms(apartment.getNumberOfRooms())
                .numberOfBedrooms(apartment.getNumberOfBedrooms())
                .haveBalconyOrTerrace(apartment.getHaveBalconyOrTerrace())
                .isFurnished(apartment.getIsFurnished())
                .buildingId(apartment.getBuilding().getBuildingId())
                .owner(ownerDto)
                .tenant(tenantDto)
                .resident(residentDto)
                .createdAt(apartment.getCreatedAt())
                .updatedAt(apartment.getUpdatedAt())
                .build();
    }

    private ResidentDto convertToDto(Resident resident) {
        return ResidentDto.builder()
                .idUsers(resident.getIdUsers())
                .fname(resident.getFname())
                .lname(resident.getLname())
                .email(resident.getEmail())
                .phoneNumber(resident.getPhoneNumber())
                .picture(resident.getPicture())
                .role(UserRole.valueOf(resident.getRole().name()))
                .accountStatus(AccountStatus.valueOf(resident.getAccountStatus().name()))
                .build();
    }
}
