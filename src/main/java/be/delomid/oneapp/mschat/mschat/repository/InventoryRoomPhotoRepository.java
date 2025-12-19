package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.InventoryRoomPhoto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface InventoryRoomPhotoRepository extends JpaRepository<InventoryRoomPhoto, UUID> {
    List<InventoryRoomPhoto> findByRoomEntry_IdOrderByOrderIndex(UUID roomEntryId);
}
