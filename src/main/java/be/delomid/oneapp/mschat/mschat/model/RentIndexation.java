package be.delomid.oneapp.mschat.mschat.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "rent_indexations")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(exclude = {"contract"})
@ToString(exclude = {"contract"})
public class RentIndexation {

    @Id
    @GeneratedValue
    @Column(name = "id")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "contract_id", nullable = false)
    private LeaseContract contract;

    @Column(name = "indexation_date", nullable = false)
    private LocalDate indexationDate;

    @Column(name = "previous_amount", nullable = false, precision = 10, scale = 2)
    private BigDecimal previousAmount;

    @Column(name = "new_amount", nullable = false, precision = 10, scale = 2)
    private BigDecimal newAmount;

    @Column(name = "indexation_rate", nullable = false, precision = 5, scale = 4)
    private BigDecimal indexationRate;

    @Column(name = "base_index", precision = 10, scale = 4)
    private BigDecimal baseIndex;

    @Column(name = "new_index", precision = 10, scale = 4)
    private BigDecimal newIndex;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
