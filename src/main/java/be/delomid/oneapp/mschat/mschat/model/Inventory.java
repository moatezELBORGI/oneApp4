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
@Table(name = "inventories")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(exclude = {"contract", "roomEntries"})
@ToString(exclude = {"contract", "roomEntries"})
public class Inventory {

    @Id
    @GeneratedValue
    @Column(name = "id")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "contract_id", nullable = false)
    private LeaseContract contract;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false)
    private InventoryType type;

    @Column(name = "inventory_date", nullable = false)
    private LocalDate inventoryDate;

    @Column(name = "electricity_meter_number")
    private String electricityMeterNumber;

    @Column(name = "electricity_day_index", precision = 10, scale = 2)
    private BigDecimal electricityDayIndex;

    @Column(name = "electricity_night_index", precision = 10, scale = 2)
    private BigDecimal electricityNightIndex;

    @Column(name = "water_meter_number")
    private String waterMeterNumber;

    @Column(name = "water_index", precision = 10, scale = 2)
    private BigDecimal waterIndex;

    @Column(name = "heating_meter_number")
    private String heatingMeterNumber;

    @Column(name = "heating_kwh_index", precision = 10, scale = 2)
    private BigDecimal heatingKwhIndex;

    @Column(name = "heating_m3_index", precision = 10, scale = 2)
    private BigDecimal heatingM3Index;

    @Column(name = "keys_apartment")
    @Builder.Default
    private Integer keysApartment = 0;

    @Column(name = "keys_mailbox")
    @Builder.Default
    private Integer keysMailbox = 0;

    @Column(name = "keys_cellar")
    @Builder.Default
    private Integer keysCellar = 0;

    @Column(name = "access_cards")
    @Builder.Default
    private Integer accessCards = 0;

    @Column(name = "parking_remotes")
    @Builder.Default
    private Integer parkingRemotes = 0;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    @Column(name = "status", nullable = false)
    private InventoryStatus status = InventoryStatus.DRAFT;

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

    @OneToMany(mappedBy = "inventory", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<InventoryRoomEntry> roomEntries = new ArrayList<>();

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
