package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.EquipmentTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EquipmentTemplateRepository extends JpaRepository<EquipmentTemplate, Long> {
    List<EquipmentTemplate> findByRoomTypeIdAndIsActiveOrderByDisplayOrder(Long roomTypeId, Boolean isActive);
    List<EquipmentTemplate> findByRoomTypeIdOrderByDisplayOrder(Long roomTypeId);
    List<EquipmentTemplate> findByIsActiveTrueOrderByRoomTypeIdAscDisplayOrderAsc();
}
