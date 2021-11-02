//
//  PDFPreviewViewController.swift
//  SE Lookup
//
//  Created by Logan Dubois on 2021-04-14.
//

import UIKit
import PDFKit

class PDFPreviewViewController: UIViewController {
    
    var pdf : Data?
    @IBOutlet weak var pdfView: PDFView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let pdfDocument = PDFDocument(data: pdf!) {
            pdfView.displayMode = .singlePageContinuous
            pdfView.autoScales = true
            pdfView.displayDirection = .vertical
            pdfView.document = pdfDocument
        }
    }
    

    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        let vc = UIActivityViewController(
          activityItems: [pdf!],
          applicationActivities: []
        )
        present(vc, animated: true, completion: nil)
    }
    
}
