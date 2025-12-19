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
        Optional<Inventory> exitInventory = inventoryRepository.findByContract_IdAndType(contractId, InventoryType.EXIT);
        return exitInventory.isPresent() && exitInventory.get().getStatus() == InventoryStatus.SIGNED;
    }

    private LeaseContractDto convertToDtoWithInventoryStatus(LeaseContract contract) {
        Optional<Inventory> entryInventory = inventoryRepository.findByContract_IdAndType(contract.getId(), InventoryType.ENTRY);
        Optional<Inventory> exitInventory = inventoryRepository.findByContract_IdAndType(contract.getId(), InventoryType.EXIT);

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
