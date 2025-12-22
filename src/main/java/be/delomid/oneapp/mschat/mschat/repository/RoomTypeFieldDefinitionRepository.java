package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.RoomTypeFieldDefinition;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RoomTypeFieldDefinitionRepository extends JpaRepository<RoomTypeFieldDefinition, Long> {
    List<RoomTypeFieldDefinition> findByRoomTypeIdOrderByDisplayOrder(Long roomTypeId);
}
