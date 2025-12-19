package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.LeaseContractArticle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface LeaseContractArticleRepository extends JpaRepository<LeaseContractArticle, UUID> {
    List<LeaseContractArticle> findByRegionCodeOrderByOrderIndex(String regionCode);
}
