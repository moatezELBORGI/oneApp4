package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.Inventory;
import be.delomid.oneapp.mschat.mschat.model.InventoryType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface InventoryRepository extends JpaRepository<Inventory, UUID> {
    List<Inventory> findByContract_Id(UUID contractId);
    Optional<Inventory> findByContract_IdAndType(UUID contractId, InventoryType type);
}
