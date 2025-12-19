package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.RentIndexation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface RentIndexationRepository extends JpaRepository<RentIndexation, UUID> {
    List<RentIndexation> findByContract_IdOrderByIndexationDateDesc(UUID contractId);
}
