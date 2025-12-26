package be.delomid.oneapp.mschat.mschat.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "lease_contracts")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(exclude = {"apartment", "owner", "tenant", "customSections", "indexations", "inventories", "entryInventory"})
@ToString(exclude = {"apartment", "owner", "tenant", "customSections", "indexations", "inventories", "entryInventory"})
public class LeaseContract {

    @Id
    @GeneratedValue
    @Column(name = "id")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "apartment_id", nullable = false)
    private Apartment apartment;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id", nullable = false)
    private Resident owner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tenant_id", nullable = false)
    private Resident tenant;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @Column(name = "initial_rent_amount", nullable = false, precision = 10, scale = 2)
    private BigDecimal initialRentAmount;

    @Column(name = "current_rent_amount", nullable = false, precision = 10, scale = 2)
    private BigDecimal currentRentAmount;

    @Column(name = "deposit_amount", precision = 10, scale = 2)
    private BigDecimal depositAmount;

    @Column(name = "charges_amount", precision = 10, scale = 2)
    private BigDecimal chargesAmount;

    @Column(name = "region_code", nullable = false)
    private String regionCode;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    @Column(name = "status", nullable = false)
    private LeaseContractStatus status = LeaseContractStatus.DRAFT;

    @Column(name = "owner_signed_at")
    private LocalDateTime ownerSignedAt;

    @Column(name = "tenant_signed_at")
    private LocalDateTime tenantSignedAt;

    @Column(name = "owner_signature_data", columnDefinition = "TEXT")
    private String ownerSignatureData;

    @Column(name = "tenant_signature_data", columnDefinition = "TEXT")
    private String tenantSignatureData;

    @Column(name = "pdf_url")
    private String pdfUrl;

    @OneToMany(mappedBy = "contract", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<LeaseContractCustomSection> customSections = new ArrayList<>();

    @OneToMany(mappedBy = "contract", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<RentIndexation> indexations = new ArrayList<>();

    @OneToMany(mappedBy = "contract", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<Inventory> inventories = new ArrayList<>();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "entry_inventory_id")
    private Inventory entryInventory;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
