package be.delomid.oneapp.mschat.mschat.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "apartment_rooms")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ApartmentRoom {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "apartment_id", nullable = false)
    private String apartmentId;

    private int orderIndex;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "room_type_id", nullable = false)
    private RoomType roomType;

    @Column(name = "room_name", length = 255)
    private String roomName;
    private String description;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "apartmentRoom", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<RoomFieldValue> fieldValues = new ArrayList<>();

    @OneToMany(mappedBy = "apartmentRoom", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<RoomEquipment> equipments = new ArrayList<>();

    @OneToMany(mappedBy = "apartmentRoom", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<RoomImage> images = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
