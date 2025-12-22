package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.RoomImage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RoomImageRepository extends JpaRepository<RoomImage, Long> {
    List<RoomImage> findByApartmentRoomIdOrderByDisplayOrder(Long apartmentRoomId);
    List<RoomImage> findByEquipmentIdOrderByDisplayOrder(Long equipmentId);
}
