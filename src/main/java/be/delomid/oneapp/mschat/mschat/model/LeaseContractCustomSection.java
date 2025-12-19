package be.delomid.oneapp.mschat.mschat.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "lease_contract_custom_sections")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(exclude = {"contract"})
@ToString(exclude = {"contract"})
public class LeaseContractCustomSection {

    @Id
    @GeneratedValue
    @Column(name = "id")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "contract_id", nullable = false)
    private LeaseContract contract;

    @Column(name = "section_title", nullable = false)
    private String sectionTitle;

    @Column(name = "section_content", nullable = false, columnDefinition = "TEXT")
    private String sectionContent;

    @Column(name = "order_index")
    @Builder.Default
    private Integer orderIndex = 0;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
