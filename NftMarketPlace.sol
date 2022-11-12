// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NftMarketPlace {

  struct Listing{

      uint256 price;
      address seller;
  }  

  error price_Zero();
  error Not_Approved();
  error Already_Listed(address nftAddress,uint256 tokenId);
  error Not_Owner();
  error Not_Listed(address nftAddress,uint256 tokenId);
  error Price_Not_Enough(address nftAddress,uint256 tokenId,uint256 price);
  error No_Proceeds();
  error Call_Falied();

  mapping (address => mapping(uint256 => Listing)) private itemLists;
  mapping (address => uint256) private proceeds;
   

  modifier notListed(address nftAddress, uint256 tokenId,address owner){
  
    Listing memory listing = itemLists[nftAddress][tokenId];
    if(listing.price > 0){

        revert Already_Listed(nftAddress,tokenId);
    }

      _;
  }

  modifier onlyOwner(

      address nftAddress,
      uint256 tokenId,
      address spender
  ){

      IERC721 nft = IERC721(nftAddress);
      address owner = nft.ownerOf(tokenId);
      if(spender != owner){

         revert Not_Owner();
      }
      _;
  }

   modifier isListed(address nftAddress,uint256 tokenId){

    Listing memory listed = itemLists[nftAddress][tokenId];
    if(listed.price <= 0){

        revert Not_Listed(nftAddress,tokenId);
    }
       _;
   }


  event ItemList(

      address indexed seller,
      address indexed nftaddress,
      uint256 indexed tokenId,
      uint256 price 
      
      );

  event ItemBought(

      address indexed buyer,
      address indexed nftAddress,
      uint256 indexed tokenId,
      uint256  price
  );
  
  event ItemCancelled(

      address indexed seller,
      address indexed nftAddress,
      uint256 tokenId
  );
  
  function ListItems(
      
      address nftAddress,
      uint256 tokenId,
      uint256 price

      ) external notListed(nftAddress,tokenId,msg.sender) onlyOwner(nftAddress,tokenId,msg.sender) {

     if(price <= 0){

         revert price_Zero();
     }

     IERC721 nft = IERC721(nftAddress);

     if(nft.getApproved(tokenId) != address(this)){

         revert Not_Approved();
     }


     itemLists[nftAddress][tokenId] = Listing(price,msg.sender);
     emit ItemList(msg.sender,nftAddress,tokenId,price);

  }

  function Buy(

     address nftAddress,
     uint256 tokenId

     )external payable isListed(nftAddress,tokenId){

     Listing memory listItem = itemLists[nftAddress][tokenId];
     if(msg.value < listItem.price){

         revert Price_Not_Enough(nftAddress,tokenId,listItem.price);
     }
      
     proceeds[listItem.seller] = proceeds[listItem.seller] + msg.value;
     delete(itemLists[nftAddress][tokenId]);
     IERC721(nftAddress).safeTransferFrom(listItem.seller,msg.sender,tokenId);
     emit ItemBought(msg.sender,nftAddress,tokenId,listItem.price);

      } 


     function CancelListing(

         address nftAddress,
         uint256 tokenId
         
         ) external onlyOwner(nftAddress,tokenId,msg.sender) isListed(nftAddress,tokenId){

          
             delete(itemLists[nftAddress][tokenId]);
             emit ItemCancelled(msg.sender,nftAddress,tokenId);


         }


        function updateListing(

            address nftAddress,
            uint256 tokenId,
            uint256 newPrice
        ) external  isListed(nftAddress ,tokenId) onlyOwner(nftAddress,tokenId,msg.sender){


         itemLists[nftAddress][tokenId].price = newPrice;
         emit ItemList(msg.sender,nftAddress,tokenId,newPrice);

        }


         function withdraw() external {

             uint256 proceed = proceeds[msg.sender];
             if(proceed <= 0){

                 revert No_Proceeds();
             }
             proceeds[msg.sender] = 0;
             (bool success,) = payable (msg.sender).call{value:proceed}("");
             if(!success){
                 revert Call_Falied();
             }
         }

       
       function getListing(

         address nftAddress,
         uint256 tokenId
           
       ) external view returns(Listing memory){

         return itemLists[nftAddress][tokenId];

       }


       function getProceeds(address seller) external view returns(uint256){

        return proceeds[seller];



       }

}


