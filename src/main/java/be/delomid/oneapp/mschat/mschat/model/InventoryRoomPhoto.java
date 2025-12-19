package be.delomid.oneapp.mschat.mschat.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "inventory_room_photos")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(exclude = {"roomEntry"})
@ToString(exclude = {"roomEntry"})
public class InventoryRoomPhoto {

    @Id
    @GeneratedValue
    @Column(name = "id")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_entry_id", nullable = false)
    private InventoryRoomEntry roomEntry;

    @Column(name = "photo_url", nullable = false)
    private String photoUrl;

    @Column(name = "caption")
    private String caption;

    @Column(name = "order_index")
    @Builder.Default
    private Integer orderIndex = 0;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
