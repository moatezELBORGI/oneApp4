package be.delomid.oneapp.mschat.mschat.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "inventory_room_entries")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(exclude = {"inventory", "apartmentRoom", "photos"})
@ToString(exclude = {"inventory", "apartmentRoom", "photos"})
public class InventoryRoomEntry {

    @Id
    @GeneratedValue
    @Column(name = "id")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inventory_id", nullable = false)
    private Inventory inventory;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "apartment_room_id")
    private ApartmentRoom apartmentRoom;

    @Column(name = "section_name")
    private String sectionName;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "order_index")
    @Builder.Default
    private Integer orderIndex = 0;

    @OneToMany(mappedBy = "roomEntry", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<InventoryRoomPhoto> photos = new ArrayList<>();

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
