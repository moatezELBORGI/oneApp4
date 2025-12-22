package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.RoomEquipment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RoomEquipmentRepository extends JpaRepository<RoomEquipment, Long> {
    List<RoomEquipment> findByApartmentRoomId(Long apartmentRoomId);
}
