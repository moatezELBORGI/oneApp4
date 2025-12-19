package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.LeaseContractCustomSection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface LeaseContractCustomSectionRepository extends JpaRepository<LeaseContractCustomSection, UUID> {
    List<LeaseContractCustomSection> findByContract_IdOrderByOrderIndex(UUID contractId);
}
