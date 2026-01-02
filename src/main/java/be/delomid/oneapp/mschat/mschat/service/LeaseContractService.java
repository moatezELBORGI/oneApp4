package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.*;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class LeaseContractService {

    private final LeaseContractRepository leaseContractRepository;
    private final ApartmentRepository apartmentRepository;
    private final ResidentRepository residentRepository;
    private final RentIndexationRepository rentIndexationRepository;
    private final LeaseContractCustomSectionRepository customSectionRepository;
    private final PdfLeaseContractGenerationService pdfGenerationService;

    @Transactional
    public LeaseContractDto createContract(CreateLeaseContractRequest request) {
        Apartment apartment = apartmentRepository.findById(request.getApartmentId())
                .orElseThrow(() -> new RuntimeException("Apartment not found"));

        Resident owner = residentRepository.findById(request.getOwnerId())
                .orElseThrow(() -> new RuntimeException("Owner not found"));

        Resident tenant = residentRepository.findById(request.getTenantId())
                .orElseThrow(() -> new RuntimeException("Tenant not found"));

        if (!apartment.getOwner().getIdUsers().equals(owner.getIdUsers())) {
            throw new RuntimeException("Only the owner of the apartment can create a lease contract");
        }

        if (leaseContractRepository.findByApartment_IdApartmentAndStatus(
                request.getApartmentId(), LeaseContractStatus.SIGNED).isPresent()) {
            throw new RuntimeException("Cannot create a new contract while an active contract exists for this apartment");
        }

        boolean isOwnerOccupant = owner.getIdUsers().equals(tenant.getIdUsers());

        LeaseContract contract = LeaseContract.builder()
                .apartment(apartment)
                .owner(owner)
                .tenant(tenant)
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .initialRentAmount(request.getInitialRentAmount())
                .currentRentAmount(request.getInitialRentAmount())
                .depositAmount(request.getDepositAmount())
                .chargesAmount(request.getChargesAmount())
                .regionCode(request.getRegionCode())
                .status(isOwnerOccupant ? LeaseContractStatus.SIGNED : LeaseContractStatus.DRAFT)
                .build();

        if (isOwnerOccupant) {
            contract.setOwnerSignedAt(LocalDateTime.now());
            contract.setTenantSignedAt(LocalDateTime.now());
        }

        contract = leaseContractRepository.save(contract);

        apartment.setTenant(tenant);
        if (isOwnerOccupant || contract.getStatus() == LeaseContractStatus.SIGNED) {
            apartment.setResident(tenant);
        }
        apartmentRepository.save(apartment);

        return convertToDto(contract);
    }

    public List<LeaseContractDto> getContractsByOwner(String ownerId) {
        return leaseContractRepository.findByOwner_IdUsers(ownerId)
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<LeaseContractDto> getContractsByTenant(String tenantId) {
        return leaseContractRepository.findByTenant_IdUsers(tenantId)
                .stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public LeaseContractDto getContractById(UUID contractId) {
        LeaseContract contract = leaseContractRepository.findById(contractId)
                .orElseThrow(() -> new RuntimeException("Contract not found"));
        return convertToDto(contract);
    }

    @Transactional
    public LeaseContractDto signContractByOwner(UUID contractId, String signatureData) {
        throw new RuntimeException("Direct contract signature is not allowed. Please complete and sign the entry inventory (état des lieux d'entrée) first. The contract will be automatically signed once the entry inventory is completed.");
    }

    @Transactional
    public LeaseContractDto signContractByTenant(UUID contractId, String signatureData) {
        throw new RuntimeException("Direct contract signature is not allowed. Please complete and sign the entry inventory (état des lieux d'entrée) first. The contract will be automatically signed once the entry inventory is completed.");
    }

    @Transactional
    public RentIndexationDto indexRent(UUID contractId, BigDecimal indexationRate, BigDecimal baseIndex, BigDecimal newIndex, String notes) {
        LeaseContract contract = leaseContractRepository.findById(contractId)
                .orElseThrow(() -> new RuntimeException("Contract not found"));

        BigDecimal previousAmount = contract.getCurrentRentAmount();
        BigDecimal newAmount = previousAmount.multiply(BigDecimal.ONE.add(indexationRate));

        RentIndexation indexation = RentIndexation.builder()
                .contract(contract)
                .indexationDate(LocalDate.now())
                .previousAmount(previousAmount)
                .newAmount(newAmount)
                .indexationRate(indexationRate)
                .baseIndex(baseIndex)
                .newIndex(newIndex)
                .notes(notes)
                .build();

        indexation = rentIndexationRepository.save(indexation);

        contract.setCurrentRentAmount(newAmount);
        leaseContractRepository.save(contract);

        return convertIndexationToDto(indexation);
    }

    public String generateContractPdf(UUID contractId) {
        try {
            String pdfUrl = pdfGenerationService.generateLeaseContractPdf(contractId);

            LeaseContract contract = leaseContractRepository.findById(contractId)
                    .orElseThrow(() -> new RuntimeException("Contract not found"));

            contract.setPdfUrl(pdfUrl);
            leaseContractRepository.save(contract);

            return pdfUrl;
        } catch (Exception e) {
            log.error("Error generating PDF for contract: {}", contractId, e);
            throw new RuntimeException("Failed to generate PDF: " + e.getMessage(), e);
        }
    }

    private LeaseContractDto convertToDto(LeaseContract contract) {
        log.info( contract.getOwner().getFname() + " " + contract.getOwner().getLname() +"//////"+
                  contract.getTenant().getFname() + " " + contract.getTenant().getLname());
        return LeaseContractDto.builder()
                .id(contract.getId().toString())
                .apartmentId(contract.getApartment().getIdApartment())
                .ownerId(contract.getOwner().getIdUsers())
                .ownerName(contract.getOwner().getFname() + " " + contract.getOwner().getLname())
                .tenantName(contract.getTenant().getFname() + " " + contract.getTenant().getLname())
                .tenantId(contract.getTenant().getIdUsers())
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
                .createdAt(contract.getCreatedAt())
                .updatedAt(contract.getUpdatedAt())
                .build();
    }

    private RentIndexationDto convertIndexationToDto(RentIndexation indexation) {
        return RentIndexationDto.builder()
                .id(indexation.getId().toString())
                .contractId(indexation.getContract().getId().toString())
                .indexationDate(indexation.getIndexationDate())
                .previousAmount(indexation.getPreviousAmount())
                .newAmount(indexation.getNewAmount())
                .indexationRate(indexation.getIndexationRate())
                .baseIndex(indexation.getBaseIndex())
                .newIndex(indexation.getNewIndex())
                .notes(indexation.getNotes())
                .createdAt(indexation.getCreatedAt())
                .build();
    }
}
