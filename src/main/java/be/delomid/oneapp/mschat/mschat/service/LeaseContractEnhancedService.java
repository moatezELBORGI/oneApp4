package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.*;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class LeaseContractEnhancedService {

    private final LeaseContractRepository leaseContractRepository;
    private final LeaseContractArticleRepository leaseContractArticleRepository;
    private final InventoryRepository inventoryRepository;
    private final ApartmentRepository apartmentRepository;
    private final ResidentRepository residentRepository;
    private final ResidentBuildingRepository residentBuildingRepository;

    public List<LeaseContractDto> getContractsByApartmentWithInventoryStatus(String apartmentId) {
        return leaseContractRepository.findByApartment_IdApartment(apartmentId)
                .stream()
                .map(this::convertToDtoWithInventoryStatus)
                .collect(Collectors.toList());
    }

    public List<LeaseContractArticleDto> getStandardArticles(String regionCode) {
        return leaseContractArticleRepository.findByRegionCodeOrderByOrderIndex(regionCode)
                .stream()
                .map(this::convertArticleToDto)
                .collect(Collectors.toList());
    }

    public boolean canTerminateContract(UUID contractId) {
        List<Inventory> exitInventories = inventoryRepository.findByContract_IdAndTypeOrderByCreatedAtDesc(contractId, InventoryType.EXIT);
        if (exitInventories.isEmpty()) {
            return false;
        }
        return exitInventories.get(0).getStatus() == InventoryStatus.SIGNED;
    }

    public List<Object> getNonResidentUsers(String search) {
        List<Resident> allResidents = residentRepository.findAll();
        List<String> residentUserIds = residentBuildingRepository.findAll()
                .stream()
                .map(rb -> rb.getResident().getIdUsers())
                .distinct()
                .collect(Collectors.toList());

        return allResidents.stream()
                .filter(resident -> !residentUserIds.contains(resident.getIdUsers()))
                .filter(resident -> {
                    if (search == null || search.trim().isEmpty()) {
                        return true;
                    }
                    String lowerSearch = search.toLowerCase();
                    return (resident.getFname() != null && resident.getFname().toLowerCase().contains(lowerSearch)) ||
                            (resident.getLname() != null && resident.getLname().toLowerCase().contains(lowerSearch)) ||
                            (resident.getEmail() != null && resident.getEmail().toLowerCase().contains(lowerSearch));
                })
                .map(resident -> {
                    ResidentDto dto = ResidentDto.builder()
                            .idUsers(resident.getIdUsers())
                            .fname(resident.getFname())
                            .lname(resident.getLname())
                            .email(resident.getEmail())
                            .phoneNumber(resident.getPhoneNumber())
                            .picture(resident.getPicture())
                            .build();
                    return (Object) dto;
                })
                .collect(Collectors.toList());
    }

    private LeaseContractDto convertToDtoWithInventoryStatus(LeaseContract contract) {
        List<Inventory> entryInventories = inventoryRepository.findByContract_IdAndTypeOrderByCreatedAtDesc(contract.getId(), InventoryType.ENTRY);
        Optional<Inventory> entryInventory = entryInventories.isEmpty() ? Optional.empty() : Optional.of(entryInventories.get(0));

        List<Inventory> exitInventories = inventoryRepository.findByContract_IdAndTypeOrderByCreatedAtDesc(contract.getId(), InventoryType.EXIT);
        Optional<Inventory> exitInventory = exitInventories.isEmpty() ? Optional.empty() : Optional.of(exitInventories.get(0));

        ResidentDto ownerDto = ResidentDto.builder()
                .idUsers(contract.getOwner().getIdUsers())
                .fname(contract.getOwner().getFname())
                .lname(contract.getOwner().getLname())
                .email(contract.getOwner().getEmail())
                .phoneNumber(contract.getOwner().getPhoneNumber())
                .picture(contract.getOwner().getPicture())
                .build();

        ResidentDto tenantDto = ResidentDto.builder()
                .idUsers(contract.getTenant().getIdUsers())
                .fname(contract.getTenant().getFname())
                .lname(contract.getTenant().getLname())
                .email(contract.getTenant().getEmail())
                .phoneNumber(contract.getTenant().getPhoneNumber())
                .picture(contract.getTenant().getPicture())
                .build();

        return LeaseContractDto.builder()
                .id(contract.getId().toString())
                .apartmentId(contract.getApartment().getIdApartment())
                .ownerId(contract.getOwner().getIdUsers())
                .owner(ownerDto)
                .tenantId(contract.getTenant().getIdUsers())
                .tenant(tenantDto)
                .startDate(contract.getStartDate())
                .endDate(contract.getEndDate())
                .initialRentAmount(contract.getInitialRentAmount())
                .currentRentAmount(contract.getCurrentRentAmount())
                .depositAmount(contract.getDepositAmount())
                .chargesAmount(contract.getChargesAmount())
                .regionCode(contract.getRegionCode())
                .status(contract.getStatus().name())
                .ownerSignedAt(contract.getOwnerSignedAt())
                .tenantSignedAt(contract.getTenantSignedAt())
                .pdfUrl(contract.getPdfUrl())
                .hasEntryInventory(entryInventory.isPresent())
                .hasExitInventory(exitInventory.isPresent())
                .createdAt(contract.getCreatedAt())
                .updatedAt(contract.getUpdatedAt())
                .build();
    }

    private LeaseContractArticleDto convertArticleToDto(LeaseContractArticle article) {
        return LeaseContractArticleDto.builder()
                .id(article.getId().toString())
                .regionCode(article.getRegionCode())
                .articleNumber(article.getArticleNumber())
                .articleTitle(article.getArticleTitle())
                .articleContent(article.getArticleContent())
                .orderIndex(article.getOrderIndex())
                .isMandatory(article.getIsMandatory())
                .build();
    }
}
