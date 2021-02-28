//
//  ImageDetailViewController.swift
//  KakaoPayHomeworkJskang
//
//  Created by 강진석 on 2021/02/26.
//

import UIKit

protocol ImageDetailViewControllerDelegate {
    func onDetailViewControllerClosed(currentIndex:Int, currentPage:Int, currentImageList:[UnsplashPhoto])
}

class ImageDetailViewController: UIViewController {
    enum Direction {
        case left
        case center
        case right
    }
    
    var imageList:[UnsplashPhoto] = [UnsplashPhoto].init() // 현재까지 로드된 이미지 목록
    var imageIndex = 0                                     // 현재화면에 보여질 이미지 번호 인덱스
    var totalPages:Int = Int.max                           // 최대 페이지 번호
    
    var detailDelegate:ImageDetailViewControllerDelegate?

    var screenWidth:CGFloat = 0                            // 화면의 가로 너비
    let gap:CGFloat = 10                                   // 좌우 이미지 사이의 간격
    var page = 1                                           // 현재까지 로드된 페이지 번호
    var query:String?                                      // 검색어 스트링
    
    var touchStartX:CGFloat = -1
    var touchStartTime:DispatchTime?
    
    @IBOutlet var nameLabel: UILabel!
    
    @IBOutlet var movingView: UIView!
    @IBOutlet var leftImageView: UIImageView!
    @IBOutlet var centerImageView: UIImageView!
    @IBOutlet var rightImageView: UIImageView!
    @IBOutlet var offsetXConstraint: NSLayoutConstraint!
    
    var leftImage:UIImage?
    var centerImage:UIImage?
    var rightImage:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setScreenWidth()
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.initImages()
        self.initImageViews()
        self.updateImageViews()
    }
    
    // 화면 너비 저장
    func setScreenWidth() {
        let screenSize: CGRect = UIScreen.main.bounds
        self.screenWidth = screenSize.width
    }
    
    // 스와이프로 오른쪽 이미지로 이동시 추가 이미지데이터 로드가 필요하다면 수행
    func loadMoreImages() {
        if self.page < self.totalPages {
            self.page += 1
            if let query = self.query, query != "" {
                UnsplashNetworkManager.shared.requestSearchPhotos(page: self.page, query: self.query ?? "") { (photos, totalPages) in
                    if let list = photos {
                        self.imageList.append(contentsOf: list)
                        self.changeImageView(direction: .right, index: self.imageIndex + 1)
                    }
                }
            }
            else {
                UnsplashNetworkManager.shared.requestAllPhotos(page: self.page) { (photos) in
                    if let list = photos {
                        self.imageList.append(contentsOf: list)
                        self.changeImageView(direction: .right, index: self.imageIndex + 1)
                    }
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    @IBAction func onClickClose(_ sender: Any) {
        // 상세화면 종료시 추가적으로 로드된 데이터들을 전달
        self.detailDelegate?.onDetailViewControllerClosed(currentIndex: self.imageIndex, currentPage: self.page, currentImageList: self.imageList)
        self.dismiss(animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: self.view) {
            self.touchStartX = location.x
            self.touchStartTime = DispatchTime.now()
        }
    }
    
    // 좌, 우 스와이프 시 오프셋 계산
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let prevLocation = touches.first?.previousLocation(in: self.view),
           let currentLocation = touches.first?.location(in: self.view) {
            self.offsetXConstraint.constant = self.offsetXConstraint.constant + (currentLocation.x - prevLocation.x)
            if self.offsetXConstraint.constant < -(self.screenWidth + self.gap) {
                self.offsetXConstraint.constant = -(self.screenWidth + self.gap)
            }
            
            if self.offsetXConstraint.constant > (screenWidth + self.gap) {
                self.offsetXConstraint.constant = (screenWidth + self.gap)
            }
            
            self.view.layoutIfNeeded()
        }
    }
    
    // 스와이프 종료시, 이동된 위치에 따라 좌측, 중앙, 우측 이동 판단하여 애니메이션
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let startTime = self.touchStartTime {
            let endTime = DispatchTime.now()
            let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
            let secondTime = Double(nanoTime) / 1000000000.0
            
            let isLastImageAndPage = ((self.imageIndex == self.imageList.count - 1) && (self.page == self.totalPages))
            // 빠르게 스와이프 된 경우 (조금만 움직여도 화면 이동)
            if secondTime < 0.25 {
                if let touchEndX:CGFloat = touches.first?.location(in: self.view).x,
                   abs(touchEndX - self.touchStartX) > self.screenWidth * 0.2 {
                    
                    // 우측 스와이프
                    if (touchEndX - self.touchStartX) < 0 && !isLastImageAndPage {
                        self.animateScreen(direction: .right)
                    }
                    // 좌측 스와이프
                    else if (touchEndX - self.touchStartX) >= 0 && self.imageIndex > 0{
                        self.animateScreen(direction: .left)
                    }
                    // 중앙에서 유지
                    else {
                        self.animateScreen(direction: .center)
                    }
                }
                else {
                    // 중앙에서 유지
                    self.animateScreen(direction: .center)
                }
            }
            // 느리게 스와이프 된 경우 (화면의 반 이상 움직여야 화면 이동)
            else {
                if self.offsetXConstraint.constant < -((self.screenWidth + self.gap) / 2.0) && !isLastImageAndPage{
                    self.animateScreen(direction: .right)
                }
                else if self.offsetXConstraint.constant < ((self.screenWidth + self.gap) / 2.0) || self.imageIndex == 0 {
                    self.animateScreen(direction: .center)
                }
                else {
                    self.animateScreen(direction: .left)
                }
            
            }
        }
    }
    
    func animateScreen(direction:Direction) {
        UIView.animate(withDuration: 0.3) {
            if direction == .right {
                self.offsetXConstraint.constant = -(self.screenWidth + self.gap)
            }
            else if direction == .center {
                self.offsetXConstraint.constant = 0
            }
            else if direction == .left {
                self.offsetXConstraint.constant = (self.screenWidth + self.gap)
            }
            self.view.layoutIfNeeded()
        } completion: { (success) in
            if direction == .right{
                self.moveRight()
            }
            else if direction == .center {
            }
            else if direction == .left {
                self.moveLeft()
            }
            self.offsetXConstraint.constant = 0
            
        }
    }
    
    // 오른쪽으로 이동하여 이미지 교체
    func moveRight() {
        self.imageIndex += 1
        self.leftImage = self.centerImage
        self.centerImage = self.rightImage
        self.rightImage = nil
        self.updateImageViews()
    }
    
    // 왼쪽으로 이동하여 이미지 교체
    func moveLeft() {
        self.imageIndex -= 1
        self.rightImage = self.centerImage
        self.centerImage = self.leftImage
        self.leftImage = nil
        self.updateImageViews()
    }
    
    // 이미지 초기화
    func initImages() {
        self.leftImage = nil
        self.centerImage = nil
        self.rightImage = nil
    }
    
    // 이미지뷰 초기화
    func initImageViews() {
        self.leftImageView.image = nil
        self.centerImageView.image = nil
        self.rightImageView.image = nil
    }
    
    // 이미지뷰 업데이트
    func updateImageViews() {
        self.updateLeftImageView()
        self.updateCenterImageView()
        self.updateRightImageView()
    }
    
    // 좌측 이미지뷰 업데이트
    func updateLeftImageView() {
        self.leftImageView.image = nil
        if imageIndex == 0 {
            return
        }
        
        if let lImage = self.leftImage {
            self.leftImageView.image = lImage
        }
        else {
            self.changeImageView(direction: .left, index: self.imageIndex - 1)
        }
    }
    
    // 중앙 이미지뷰 업데이트
    func updateCenterImageView() {
        if let cImage = self.centerImage {
            self.centerImageView.image = cImage
            if self.imageIndex < self.imageList.count {
                self.nameLabel.text = self.imageList[self.imageIndex].user.name
            }
        }
        else {
            self.changeImageView(direction: .center, index: self.imageIndex)
        }
    }
    
    // 우측 이미지뷰 업데이트
    func updateRightImageView() {
        self.rightImageView.image = nil
        if let rImage = self.rightImage {
            self.rightImageView.image = rImage
        }
        else {
            if imageList.count <= self.imageIndex + 1 {
                self.loadMoreImages()
            }
            else {
                self.changeImageView(direction: .right, index: self.imageIndex + 1)
            }
        }
    }
    
    func changeImageView(direction:Direction, index:Int) {
        guard index < imageList.count, let url = self.imageList[index].urls[.small] else { return }
        DispatchQueue.global().async {
            let data = try? Data(contentsOf: url)
            if let imageData = data {
                let image = UIImage(data: imageData)
                DispatchQueue.main.async {
                    if direction == .left {
                        self.leftImage = image
                        self.leftImageView.image = image
                    }
                    else if direction == .center {
                        self.centerImage = image
                        self.centerImageView.image = image
                        self.nameLabel.text = self.imageList[index].user.name
                    }
                    else if direction == .right {
                        self.rightImage = image
                        self.rightImageView.image = image
                    }
                }
            }
        }
    }

}
