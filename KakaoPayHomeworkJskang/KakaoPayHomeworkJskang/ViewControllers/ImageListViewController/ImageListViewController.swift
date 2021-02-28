//
//  ViewController.swift
//  KakaoPayHomeworkJskang
//
//  Created by 강진석 on 2021/02/26.
//

import UIKit

class ImageListViewController: UIViewController {
    
    var detailViewController:ImageDetailViewController?
    
    var imageList:[UnsplashPhoto] = [UnsplashPhoto].init()  // 테이블뷰 이미지 목록
    var page:Int = 1                                        // 테이블뷰 페이징을 위한 페이지 번호
    var totalPage:Int = Int.max                             // 최대 페이지 번호 (전체보기에서는 무한, 검색시에는 서버에서 받아서 저장)
    var query:String?                                       // 검색어 스트링
    var preLoadAreaHeight:CGFloat = 1000                    // 프리로드를 위한 테이블뷰 영역 높이
    
    var isLoadingImages = false
    var isMore = false
    @IBOutlet var loadingView: UIActivityIndicatorView!
    
    @IBOutlet var tableViewBottonConstraint: NSLayoutConstraint!
    @IBOutlet var tableViewTopConstraint: NSLayoutConstraint!

    
    
    @IBOutlet var imageListTableView: UITableView!
    @IBOutlet var searchTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initDetailViewController()
        self.settingImageListTableView()
        self.settingSearchTextField()
        self.loadImages()
    }
    
    // 전체 이미지 로드
    func loadImages() {
        self.isLoadingImages = true
        self.query = ""
        self.totalPage = Int.max
        
        self.loadingView.isHidden = false
        self.loadingView.startAnimating()
        
        UnsplashNetworkManager.shared.requestAllPhotos(page: self.page) { (photos) in
            self.reloadTableView(photos: photos)
        }
    }
    
    // 특정 키워드로 검색된 이미지 로드
    func searchImages() {
        self.isLoadingImages = true
        self.query = self.searchTextField.text
        
        self.loadingView.isHidden = false
        self.loadingView.startAnimating()
        
        UnsplashNetworkManager.shared.requestSearchPhotos(page: self.page, query: self.query ?? "") { (photos, totalPages) in
            self.totalPage = totalPages
            self.reloadTableView(photos: photos)
        }
    }
    
    // 데이터와 테이블뷰 갱신
    func reloadTableView(photos:[UnsplashPhoto]?) {
        DispatchQueue.main.async {
            self.loadingView.isHidden = true
            self.loadingView.stopAnimating()
            
            if let list = photos {
                self.imageList.append(contentsOf: list)
            }
            
            self.imageListTableView.reloadData()
            
            if !self.isMore {
                if self.imageList.count > 0 {
                    
                    self.imageListTableView.scrollToRow(at: IndexPath.init(row: 0, section: 0), at: .top, animated: false)
                }
            }
            self.isMore = false
            self.isLoadingImages = false
        }
    }
    
    func settingImageListTableView() {
        self.imageListTableView.showsVerticalScrollIndicator = false
        self.imageListTableView.showsHorizontalScrollIndicator = false
        self.imageListTableView.layoutMargins = .zero
        self.imageListTableView.allowsSelection = true
        self.imageListTableView.allowsMultipleSelection = false
        self.imageListTableView.separatorStyle = .none
        self.imageListTableView.register(UINib(nibName: "ImageListCell", bundle: nil), forCellReuseIdentifier: ImageListCell.description())
        self.imageListTableView.delegate = self
        self.imageListTableView.dataSource = self
        self.imageListTableView.contentInset.top = self.preLoadAreaHeight - 20
        self.imageListTableView.contentInset.bottom = self.preLoadAreaHeight
        self.tableViewTopConstraint.constant = -self.preLoadAreaHeight
        self.tableViewBottonConstraint.constant = -self.preLoadAreaHeight
        self.view.setNeedsLayout()
    }
    
    func settingSearchTextField() {
        self.searchTextField.delegate = self
    }
    
    func initDetailViewController() {
        self.detailViewController = ImageDetailViewController.init(nibName: "ImageDetailViewController", bundle:nil)
        self.detailViewController?.modalPresentationStyle = .fullScreen
        self.detailViewController?.detailDelegate = self
    }
    
    
}

extension ImageListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.imageList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let uCell = tableView.dequeueReusableCell(withIdentifier: ImageListCell.description()) as? ImageListCell else {
            return UITableViewCell()
        }
        uCell.updateData(imageData: self.imageList[indexPath.row])
        
        return uCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let viewWidth = self.view.frame.size.width
        let imageWidth = CGFloat(self.imageList[indexPath.row].width)
        let imageHeight = CGFloat(self.imageList[indexPath.row].height)
        return viewWidth / imageWidth * imageHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 이미지 상세화면 렌딩
        if let vc = self.detailViewController {
            vc.imageList = self.imageList
            vc.imageIndex = indexPath.row
            vc.page = self.page
            vc.query = self.query
            vc.totalPages = self.totalPage
            self.present(vc, animated: true)
        }
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 스크롤이 바텀에 도달하면 다음 페이지 로드
        if (scrollView.contentOffset.y > (scrollView.contentSize.height - scrollView.frame.size.height)) {
            if !self.isLoadingImages && self.page < self.totalPage {
                //print("loading")
                self.isLoadingImages = true
                self.page = self.page + 1
                self.isMore = true
                if self.searchTextField.text != nil && self.searchTextField.text != "" {
                    self.searchImages()
                }
                else {
                    self.loadImages()
                }
            }
        }
    }
    

}

extension ImageListViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        if textField.text == nil {
            return false
        }
        
        self.page = 1
        self.imageList.removeAll()
        
        if textField.text == "" {
            self.loadImages()
        }
        else {
            self.searchImages()
        }
        return false
    }
}

extension ImageListViewController: ImageDetailViewControllerDelegate {
    
    // 상세 화면에서 돌아오면 해당 이미지 위치로 스크롤 이동
    // 추가 로드되었던 이미지 목록도 업데이트
    func onDetailViewControllerClosed(currentIndex:Int, currentPage:Int, currentImageList:[UnsplashPhoto]) {
        if self.page != currentPage {
            self.page = currentPage
            self.imageList = currentImageList
            self.imageListTableView.reloadData()
        }
        
        let moveToIndexPath = IndexPath.init(row: currentIndex, section: 0)
        self.imageListTableView.scrollToRow(at: moveToIndexPath, at: .bottom, animated: false)
    }
}

