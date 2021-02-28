//
//  ImageListCell.swift
//  KakaoPayHomeworkJskang
//
//  Created by 강진석 on 2021/02/26.
//

import UIKit

class ImageListCell: UITableViewCell {

    @IBOutlet var prepareView: UIView!
    @IBOutlet var screenImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    
    var imageData:UnsplashPhoto? // 현재 셀에 나타낼 이미지 데이터
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func updateData(imageData:UnsplashPhoto) {
        self.imageData = imageData
        self.updateUI()
    }
    
    override func prepareForReuse() {
        self.prepareView.isHidden = false
    }
    
    func updateUI() {
        self.nameLabel.text = self.imageData?.user.name
        
        guard let url = self.imageData?.urls[.small] else { return }
        
        // 외부 이미지 로드는 비동기 처리 후, 메인 UI 쓰레드에서 이미지 뷰 업데이트
        DispatchQueue.global().async {
            let data = try? Data(contentsOf: url)
            if let imageData = data {
                let image = UIImage(data: imageData)
                DispatchQueue.main.async {
                    self.prepareView.isHidden = true
                    self.screenImageView.image = image
                }
            }
        }
        
    }
    
}
