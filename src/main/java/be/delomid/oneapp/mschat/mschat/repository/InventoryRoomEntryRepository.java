package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.InventoryRoomEntry;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface InventoryRoomEntryRepository extends JpaRepository<InventoryRoomEntry, UUID> {
    List<InventoryRoomEntry> findByInventory_IdOrderByOrderIndex(UUID inventoryId);
}
