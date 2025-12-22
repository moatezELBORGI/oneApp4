package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.RoomFieldValue;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RoomFieldValueRepository extends JpaRepository<RoomFieldValue, Long> {
    List<RoomFieldValue> findByApartmentRoomId(Long apartmentRoomId);
}
