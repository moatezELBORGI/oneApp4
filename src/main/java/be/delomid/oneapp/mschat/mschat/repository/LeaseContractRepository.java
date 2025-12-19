package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.LeaseContract;
import be.delomid.oneapp.mschat.mschat.model.LeaseContractStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface LeaseContractRepository extends JpaRepository<LeaseContract, UUID> {
    List<LeaseContract> findByOwner_IdUsers(String ownerId);
    List<LeaseContract> findByTenant_IdUsers(String tenantId);
    List<LeaseContract> findByApartment_IdApartment(String apartmentId);
    Optional<LeaseContract> findByApartment_IdApartmentAndStatus(String apartmentId, LeaseContractStatus status);
    List<LeaseContract> findByOwner_IdUsersAndStatus(String ownerId, LeaseContractStatus status);
    List<LeaseContract> findByTenant_IdUsersAndStatus(String tenantId, LeaseContractStatus status);
}
